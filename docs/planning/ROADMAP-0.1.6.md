# Roadmap: 0.1.6 - Shopping List & Polish

**Milestone:** 0.1.6 - Shopping List & Polish
**Status:** Planning
**Total Issues:** 6
**Total Points:** 20
**Start Date:** January 22, 2026
**Target Completion:** January 30, 2026
**Sprint Duration:** 9 days

---

## Milestone Overview

**Theme:** Complete the core meal planning workflow with shopping list generation, plus final polish for 0.1.x series.

**Goals:**
1. Implement shopping list generation from meal plans (#5)
2. Fix critical UX gap - recipe navigation from meal plan (#33)
3. Improve code architecture and polish (#231, #196, #242)
4. Add meal summary analytics to weekly plan (#32)

**Success Criteria:**
- Users can generate shopping lists from their weekly meal plans
- Users can view recipe details directly from the meal plan
- RecipesScreen properly extracted from HomePage
- "To Taste" ingredients display correctly
- RegExp deprecation warnings resolved
- Meal summary section provides insights on weekly plan

**Milestone Significance:**

This is the **final milestone of the 0.1.x series**, completing the core meal planning workflow:
- ✅ Recipe management (0.1.0)
- ✅ Meal planning and tracking (0.1.0)
- ✅ Recommendation engine (0.1.0)
- ✅ Testing infrastructure (0.1.1-0.1.5)
- ✅ Architecture consolidation (0.1.3-0.1.4)
- 🎯 Shopping list generation (0.1.6) ← Final piece

After 0.1.6, the app will have a complete **meal planning → shopping workflow** ready for the 0.2.0 beta phase.

---

## Issues Summary

| # | Title | Type | Priority | Points | Category |
|---|-------|------|----------|--------|----------|
| #5 | Shopping List Generation | Feature | P1-High | 8 | Major Feature |
| #32 | Meal summary section | Feature | ✓✓ | 5 | Feature |
| #33 | Recipe navigation from meal plan | UX Fix | ✓✓✓ | 3 | Critical UX |
| #242 | Fix RegExp deprecation warnings | Tech Debt | P3-Low | 2 | Cleanup |
| #196 | "To Taste" ingredients display | Polish | ✓✓ | 1 | Polish |
| #231 | Extract RecipesScreen refactor | Refactor | ✓✓ | 1 | Architecture |
| **TOTAL** | | | | **20** | |

---

## Estimation Details

### Planning Poker Results

**Issue #32 - Meal summary section (5 points)**
- New `WeeklyPlanSummaryWidget` component
- Protein distribution, time allocation, variety metrics
- Warnings for planning issues
- Scope: Keep simple as foundation for future refinements
- Estimated as: Medium complexity

**Issue #33 - Recipe navigation (3 points - MVP scope)**
- Navigation from meal plan to recipe details
- MVP scope: Basic navigation + state refresh
- Deferred: Custom animations, sophisticated caching
- Estimated as: Small-to-medium task

**Issue #242 - RegExp warnings (2 points)**
- Fix 4 deprecation warnings in `tools/ingredient_normalizer.dart`
- Well-documented with clear investigation path
- Estimated as: Small but not trivial

**Issue #254 - Fix dialog test (moved to 0.2.0)**
- Originally 3 points
- Debugging task with some uncertainty
- Deferred to focus on features

**Issue #28 - Configurable week start (moved to 0.2.0)**
- Originally 8 points
- Cross-cutting change affecting multiple system layers
- Too complex for this sprint, lower priority

**Pre-estimated issues:**
- #5 - Shopping List: 8 points (major feature)
- #196 - "To Taste": 1 point (small polish)
- #231 - Extract RecipesScreen: 1 point (simple refactor)
- #241 - Date picker tests: 3 points (moved to 0.2.0)

---

## Dependency Graph

```
Phase 1: Foundation (Independent)
  ├──► #231 (Extract RecipesScreen) - Do first for architecture
  ├──► #242 (RegExp warnings) - Quick cleanup
  └──► #196 ("To Taste" ingredients) - Small polish

Phase 2: Critical UX (Independent)
  └──► #33 (Recipe navigation) - High priority UX fix

Phase 3: Major Feature (Independent)
  └──► #5 (Shopping List Generation) - Core feature, needs focus

Phase 4: Enhanced Feature (Flexible)
  └──► #32 (Meal summary) - Can defer to 0.2.0 if needed
```

**Key Dependencies:**
- **All issues are independent** - No blocking dependencies
- **#231 recommended first** - Improves architecture for other work
- **#32 is flexible** - Can move to 0.2.0 if timeline is tight

---

## Recommended Execution Order

### Phase 1: Foundation & Quick Wins (Jan 22-23, ~4 pts)

| Order | Issue | Points | Priority | Reason |
|-------|-------|--------|----------|--------|
| 1 | #231 | 1 | Architecture | Do first - improves code structure |
| 2 | #242 | 2 | Tech Debt | Quick cleanup, clears warnings |
| 3 | #196 | 1 | Polish | Small improvement, easy win |

**Phase 1 Goals:**
- Clean up technical debt
- Improve architecture
- Build momentum with quick wins

### Phase 2: Critical UX (Jan 24, ~3 pts)

| Order | Issue | Points | Priority | Reason |
|-------|-------|--------|----------|--------|
| 4 | #33 | 3 | HIGH ✓✓✓ | Close critical UX gap, MVP scope only |

**Phase 2 Goals:**
- Fix high-priority user experience issue
- Enable users to view recipes from meal plan

### Phase 3: Major Feature (Jan 25-28, ~8 pts)

| Order | Issue | Points | Priority | Reason |
|-------|-------|--------|----------|--------|
| 5 | #5 | 8 | P1-High | Main milestone deliverable, needs focus |

**Phase 3 Goals:**
- Implement shopping list generation (core feature)
- MVP approach: basic list generation, defer advanced features
- Complete the meal planning → shopping workflow

### Phase 4: Enhanced Feature (Jan 29-30, ~5 pts)

| Order | Issue | Points | Priority | Reason |
|-------|-------|--------|----------|--------|
| 6 | #32 | 5 | Medium ✓✓ | Valuable analytics feature, keep simple |

**Phase 4 Goals:**
- Add meal summary section if time permits
- Final testing and polish
- Can defer to 0.2.0 if needed

---

## Execution Phases - Detailed Breakdown

### Phase 1: Foundation & Quick Wins (Days 1-2, Jan 22-23)

**Target: 4 points**

#### Issue #231: Extract RecipesScreen from HomePage (1 pt)
- **Branch:** `refactor/231-extract-recipes-screen`
- **Type:** Architecture refactoring
- **Effort:** 1-2 hours
- **Tasks:**
  - Extract RecipesScreen into separate file
  - Update HomePage to use extracted component
  - Verify all functionality still works
  - Run `flutter analyze` and tests

#### Issue #242: Fix RegExp deprecation warnings (2 pts)
- **Branch:** `bugfix/242-regexp-deprecation-warnings`
- **Type:** Technical debt cleanup
- **Effort:** 1-2 hours
- **Tasks:**
  - Investigate proper solution (Pattern type, RegExp.escape alternatives)
  - Fix 4 warnings in `tools/ingredient_normalizer.dart`
  - Test the tool still works correctly
  - Run `flutter analyze` to verify warnings cleared

#### Issue #196: Improve "To Taste" ingredients (1 pt)
- **Branch:** `feature/196-to-taste-ingredients`
- **Type:** UI/Model polish
- **Effort:** 1-2 hours
- **Tasks:**
  - Update model for zero-quantity ingredients
  - Improve UI display for "To Taste" items
  - Add/update tests
  - Update localization if needed

**Phase 1 Completion Target:** End of Day 2 (Jan 23)

---

### Phase 2: Critical UX (Day 3, Jan 24)

**Target: 3 points**

#### Issue #33: Recipe navigation from meal plan (3 pts - MVP)
- **Branch:** `feature/33-recipe-details-navigation`
- **Type:** UX Fix
- **Effort:** 4-6 hours
- **MVP Scope (documented in issue comment):**
  - Implement navigation from meal plan to existing recipe details screen
  - Handle `_handleMealTap` 'view' action
  - Basic recipe data loading
  - Standard back navigation returns to meal plan
  - Simple state refresh on return (if recipe was edited)
- **Out of Scope:**
  - Custom transition animations (use Flutter defaults)
  - Sophisticated caching mechanisms
  - Custom "Back to Meal Plan" button
  - Advanced state management optimizations
- **Tasks:**
  - Locate existing recipe details screen
  - Implement navigation in `_handleMealTap`
  - Add state refresh mechanism
  - Test navigation flow
  - Update tests

**Phase 2 Completion Target:** End of Day 3 (Jan 24)

---

### Phase 3: Major Feature (Days 4-6, Jan 25-28)

**Target: 8 points**

#### Issue #5: Shopping List Generation (8 pts)
- **Branch:** `feature/5-shopping-list-generation`
- **Type:** Major Feature
- **Effort:** 12-16 hours (2-3 days)
- **Sub-tasks:**
  1. **Data Model & Database** (Day 1)
     - Create ShoppingList model
     - Create ShoppingListItem model
     - Add database tables and migrations
     - Add CRUD operations to DatabaseHelper

  2. **Algorithm & Business Logic** (Day 2)
     - Implement ingredient aggregation algorithm
     - Handle unit conversion/normalization
     - Implement category-based grouping
     - Add ingredient matching logic

  3. **UI Implementation** (Day 3)
     - Create shopping list screen
     - Add list generation from meal plan
     - Implement "mark as purchased" functionality
     - Add manual quantity adjustments
     - Implement localization

  4. **Testing & Polish**
     - Unit tests for algorithm
     - Widget tests for UI
     - Integration tests for workflow
     - Edge cases (empty plans, single recipe, etc.)

- **MVP Approach:**
  - Focus on core functionality: generate, display, mark purchased
  - Defer advanced features (export/share, complex unit conversions)
  - Keep UI simple and functional

**Phase 3 Completion Target:** End of Day 6 (Jan 28)

---

### Phase 4: Enhanced Feature & Polish (Days 7-9, Jan 29-30)

**Target: 5 points + buffer**

#### Issue #32: Meal summary section (5 pts)
- **Branch:** `feature/32-meal-summary-section`
- **Type:** Feature
- **Effort:** 8-12 hours (1-1.5 days)
- **Keep Simple Approach:**
  - Use basic Flutter widgets (no external charting library)
  - Text-based metrics with simple progress indicators
  - Foundation for future enhancements
- **Tasks:**
  1. **Statistics Calculation**
     - Create utility class for meal plan metrics
     - Protein distribution by day
     - Cooking time allocation
     - Recipe variety metrics (unique, repeats)

  2. **UI Component**
     - Create `WeeklyPlanSummaryWidget`
     - Display protein distribution (simple list/bars)
     - Show time allocation by day
     - Display variety metrics

  3. **Warnings Logic**
     - Detect repeated proteins back-to-back
     - Flag unbalanced meal patterns
     - Keep logic simple

  4. **Integration**
     - Add to WeeklyPlanScreen (tab or expandable)
     - Toggle show/hide functionality
     - Ensure real-time updates

  5. **Testing**
     - Unit tests for statistics calculation
     - Widget tests for summary component
     - Edge cases (empty week, partial week)

- **Flexibility:** If timeline is tight, defer to 0.2.0

#### Final Sprint Activities
- **Integration Testing:** Test complete workflows
- **Documentation:** Update CHANGELOG.md
- **Polish:** Final bug fixes and refinements
- **Release Prep:** Prepare for 0.1.6 release

**Phase 4 Completion Target:** End of Day 9 (Jan 30)

---

## Risk Mitigation

### High Risk Items

**Issue #5 (Shopping List) - 8 points**
- **Risk:** Scope creep, complexity in ingredient aggregation
- **Mitigation:**
  - Start with MVP (basic list generation)
  - Defer advanced features (export, complex conversions) to 0.2.0
  - Focus on core algorithm first, polish UI later
- **Fallback:** Implement core algorithm + basic UI, defer polish to 0.2.0

**Issue #32 (Meal Summary) - 5 points**
- **Risk:** Data visualization complexity, scope uncertainty
- **Mitigation:**
  - Keep simple: text-based metrics, basic widgets
  - No external charting libraries
  - Foundation only, enhance later
- **Fallback:** Move entirely to 0.2.0 if timeline is tight

### Scope Management Strategy

**Must Complete (14 points):**
- ✅ #5 - Shopping List (8 pts) - Main milestone deliverable
- ✅ #33 - Recipe navigation (3 pts) - HIGH priority UX
- ✅ #231 - RecipesScreen refactor (1 pt) - Architecture
- ✅ #242 - RegExp warnings (2 pts) - Tech debt

**Should Complete (6 points):**
- ✅ #196 - "To Taste" improvements (1 pt) - Quick polish
- ⚠️ #32 - Meal summary (5 pts) - Valuable but flexible

**Decision Point:** End of Day 6 (Jan 28)
- If on track: Proceed with #32
- If behind: Defer #32 to 0.2.0, focus on testing and polish

---

## Sprint Calendar

```
Wed Jan 22 (Day 1):
  - #231 Extract RecipesScreen (1 pt)
  - #242 RegExp warnings (2 pts)
  - Start #196 "To Taste"

Thu Jan 23 (Day 2):
  - Complete #196 "To Taste" (1 pt)
  - Start #33 Recipe navigation

Fri Jan 24 (Day 3):
  - Complete #33 Recipe navigation (3 pts)
  ✓ Checkpoint: 7 points completed

Sat Jan 25 (Day 4):
  - Start #5 Shopping List
  - Data models & database

Sun Jan 26 (Day 5):
  - Continue #5 Shopping List
  - Algorithm & business logic

Mon Jan 27 (Day 6):
  - Continue #5 Shopping List
  - UI implementation

Tue Jan 28 (Day 7):
  - Complete #5 Shopping List (8 pts)
  - Testing & polish
  ✓ Decision Point: Proceed with #32 or wrap up?

Wed Jan 29 (Day 8):
  - #32 Meal summary section (5 pts)
  - OR: Integration testing if #32 deferred

Thu Jan 30 (Day 9):
  - Complete #32 or final polish
  - Integration testing
  - Documentation updates
  - Release prep
```

---

## Issues Moved to 0.2.0

The following issues were originally in 0.1.6 but moved to 0.2.0 during planning:

| # | Title | Points | Reason |
|---|-------|--------|--------|
| #28 | Configurable week start day | 8 | Complex cross-cutting change, lower priority |
| #241 | Date picker tests | 3 | Testing improvement, not critical |
| #254 | Fix AddSideDishDialog test | 3 | Testing improvement, not critical |

**Total deferred:** 14 points

**Rationale:** Focus sprint on delivering actual features (#5 shopping list, #33 navigation) and critical cleanup rather than testing improvements. Keeps sprint at realistic 20 points for 9 days.

---

## Success Metrics

### Definition of Done

**For the Sprint:**
- All "Must Complete" issues (#5, #33, #231, #242) delivered and tested
- Shopping list workflow works end-to-end
- Recipe navigation from meal plan functional
- All tests passing: `flutter test && flutter analyze`
- CHANGELOG.md updated
- No regressions in existing functionality

**For the Milestone:**
- Users can generate shopping lists from weekly meal plans
- Complete meal planning → shopping workflow functional
- Critical UX gaps closed
- Architecture improved
- Technical debt reduced
- Ready for 0.2.0 beta phase

### Quality Gates

- ✅ All issues pass code review
- ✅ Test coverage maintained or improved
- ✅ No new analyzer warnings
- ✅ Localization complete (EN + PT)
- ✅ Edge cases tested and handled
- ✅ Documentation updated

---

## Post-Sprint Activities

1. **Release 0.1.6**
   - Tag release in git
   - Update milestone description with completion status
   - Close completed issues

2. **Retrospective**
   - What went well?
   - What could be improved?
   - Adjust estimation for 0.2.0

3. **Plan 0.2.0**
   - Review deferred issues (#28, #241, #254)
   - Add new beta-ready phase features
   - Estimate and prioritize

---

## Notes

- This is the final 0.1.x release
- Focus is on completing core workflow, not perfection
- MVP approach preferred for complex features
- Flexibility built in (#32 can defer if needed)
- 20 points for 9 days = ~2.2 points/day average (realistic)

---

**Document Status:** Final
**Last Updated:** January 12, 2026
**Next Review:** January 30, 2026 (sprint completion)
